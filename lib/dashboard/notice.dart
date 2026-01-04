import 'package:flutter/material.dart';

final List<String> notices = [
  "School closed on 30th June due to weather.",
  "Parent-Teacher Meeting on 1st July.",
  "New Uniform guidelines updated.",
  "Mid-term exam begins on 10th July.",
  "Holiday announced on 12th August for Independence Day prep.",
  "Library will remain open till 5 PM from 1st July.",
];

final List<String> events = [
  "Science Exhibition – 5th July",
  "Annual Sports Day – 15th July",
  "Independence Day Prep – 10th Aug",
  "Mid-term exam begins on 10th July.",
  "Holiday announced on 12th August for Independence Day prep.",
  "Library will remain open till 5 PM from 1st July.",
];
Widget buildNoticesEventsTab() {
  return DefaultTabController(
    length: 2,
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            indicatorColor: Colors.deepPurple,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "📰 Notices"),
              Tab(text: "📅 Events"),
            ],
          ),
          SizedBox(
            height: 180, // adjust height
            child: TabBarView(
              children: [
                // Notices Tab
                ListView.builder(
                  itemCount: notices.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.announcement, color: Colors.deepPurple),
                    title: Text(notices[index]),
                  ),
                ),
                // Events Tab
                ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.event, color: Colors.teal),
                    title: Text(events[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
