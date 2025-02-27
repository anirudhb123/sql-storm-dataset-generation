
SELECT
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    (SELECT COUNT(*) FROM Tags) AS TotalTags,
    (SELECT COUNT(*) FROM PostHistory) AS TotalPostHistory
GROUP BY 1, 2, 3, 4, 5, 6, 7
