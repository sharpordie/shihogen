import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_plus/mvvm_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shihogen/widgets/own_appbar.dart';
import 'package:shihogen/widgets/own_header.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class LauncherView extends ViewWidget<LauncherViewModel> {
  LauncherView({super.key}) : super(builder: () => LauncherViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OwnAppBar(
        btnText: 'Done',
        loading: viewModel.loading.value,
        onClick: () async => await viewModel.onDoneClicked(),
      ),
      body: Column(
        children: [
          const OwnHeader(
            heading: 'Launcher',
            message: 'Choose your background',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: PageView.builder(
                itemCount: viewModel.pictureItems.length,
                controller: viewModel.pictureController,
                onPageChanged: (changed) {
                  viewModel.picture.value = viewModel.pictureItems[changed];
                  viewModel.pictureIndex.value = changed;
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                    child: CachedNetworkImage(
                      imageUrl: 'https://www.themoviedb.org/t/p/w1280/${viewModel.pictureItems[index]}.jpg',
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: AnimatedSmoothIndicator(
              activeIndex: viewModel.pictureIndex.value,
              count: viewModel.pictureItems.length,
              onDotClicked: (index) => viewModel.pictureController.jumpToPage(index),
              effect: WormEffect(
                dotColor: Theme.of(context).colorScheme.secondaryContainer,
                activeDotColor: Theme.of(context).colorScheme.primary,
                radius: 0,
                spacing: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LauncherViewModel extends ViewModel {
  late final SharedPreferences sharing;
  late final loading = createProperty<bool>(false);
  late final picture = createProperty(pictureItems.first);
  late final pictureIndex = createProperty(0);
  late final pictureController = PageController();
  late final pictureItems = [
    'kI9tiDhDpeav28nlwDwTUbUwiSx', // Avatar
    'e0Ro7wajZoxKWdhaisjchalEzh0', // American Horror Story
    '1gGRY9bnIc0Jaohgc6jNFidjgLK', // American Horror Story
    'rqbCbjB19amtOtFQbb3K2lgm2zv', // Attack on Titan
    '4e36PN10oS3x2zJtE30Del0uEHS', // Krampus
    'k5qfeGVD6yY0HXYveMT6isJTbJG', // Stranger Things
    '9zcbqSxdsRMZWHYtyCd1nXPr2xq', // The Mandalorian
    's56eyXy8rADp5DpZknfe2HXq4u4', // The Witcher
    'iHSwvRVsRyxpX7FE7GbviaDvgGZ', // Wednesday
  ];

  @override
  void initState() {
    super.initState();
    () async {
      sharing = await SharedPreferences.getInstance();
    }();
  }

  Future<void> onDoneClicked() async {
    loading.value = true;
    const segment = 'https://www.themoviedb.org/t/p/original/';
    await sharing.setString('picture', '$segment/${picture.value}.jpg');
    if (context.mounted) await Navigator.pushNamed(context, '/settings');
    loading.value = false;
  }
}
