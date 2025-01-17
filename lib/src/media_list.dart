import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../media_picker_widget.dart';
import 'header_controller.dart';
import 'widgets/media_tile.dart';

class MediaList extends StatefulWidget {
  MediaList({
    required this.album,
    required this.headerController,
    this.mediaCount,
    this.decoration,
    this.maxSelected,
    this.scrollController,
    required this.onTapCamera,
  });

  final AssetPathEntity album;
  final HeaderController headerController;
  final MediaCount? mediaCount;
  final PickerDecoration? decoration;
  final ScrollController? scrollController;
  final Function() onTapCamera;
  final int? maxSelected;

  @override
  _MediaListState createState() => _MediaListState();
}

class _MediaListState extends State<MediaList> {
  List<AssetEntity> _mediaList = [];
  int currentPage = 0;
  int? lastPage;
  bool empty = false;
  AssetPathEntity? album;
  List<AssetEntity> selectedMedias = [];

  @override
  void initState() {
    album = widget.album;
    _fetchNewMedia();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MediaList oldWidget) {
    _resetAlbum();
    super.didUpdateWidget(oldWidget);
  }

  _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchNewMedia();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      addAutomaticKeepAlives: false,
      physics: BouncingScrollPhysics(),
      controller: widget.scrollController,
      itemCount: _mediaList.length + 1,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          crossAxisCount: widget.decoration!.columnCount),
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) {
          return InkWell(
            onTap: widget.onTapCamera,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 36,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      Text(
                        'Chụp ảnh',
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.5), fontSize: 16),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        }
        final index = i - 1;
        if (index == _mediaList.length - 20 && !empty) {
          _fetchNewMedia();
        }
        return MediaTile(
          totalSelect: selectedMedias.length,
          maxSelect: widget.maxSelected,
          media: _mediaList[index],
          onSelected: (isSelected, media) {
            if (isSelected) {
              setState(() => selectedMedias.add(media));
            } else
              setState(() => selectedMedias
                  .removeWhere((_media) => _media.id == media.id));
            widget.headerController.updateSelection!(selectedMedias);
          },
          isSelected: isPreviouslySelected(_mediaList[index]),
          decoration: widget.decoration,
        );
      },
    );
  }

  _resetAlbum() {
    if (album != null) {
      if (album!.id != widget.album.id) {
        _mediaList.clear();
        album = widget.album;
        currentPage = 0;
        _fetchNewMedia();
      }
    }
  }

  _fetchNewMedia() async {
    lastPage = currentPage;
    var result = await PhotoManager.requestPermissionExtend();
    if (result == PermissionState.limited ||
        result == PermissionState.authorized) {
      List<AssetEntity> media = await album!.getAssetListPaged(currentPage, 80);
      setState(() {
        empty = media.isEmpty;
        _mediaList.addAll(media);
        currentPage++;
      });
    } else {
      PhotoManager.openSetting();
    }
  }

  bool isPreviouslySelected(AssetEntity media) {
    bool isSelected = false;
    for (var asset in selectedMedias) {
      if (asset.id == media.id) isSelected = true;
    }
    return isSelected;
  }
}
