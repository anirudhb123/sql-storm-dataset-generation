
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Tags) AS TotalTags,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    (SELECT COUNT(*) FROM PostHistory) AS TotalPostHistory,
    (SELECT COUNT(*) FROM PostLinks) AS TotalPostLinks,
    (SELECT COUNT(*) FROM LinkTypes) AS TotalLinkTypes,
    (SELECT COUNT(*) FROM PostTypes) AS TotalPostTypes,
    (SELECT COUNT(*) FROM CloseReasonTypes) AS TotalCloseReasons,
    (SELECT COUNT(*) FROM VoteTypes) AS TotalVoteTypes,
    (SELECT COUNT(*) FROM PostHistoryTypes) AS TotalPostHistoryTypes
GROUP BY 
    (SELECT COUNT(*) FROM Posts),
    (SELECT COUNT(*) FROM Comments),
    (SELECT COUNT(*) FROM Votes),
    (SELECT COUNT(*) FROM Users),
    (SELECT COUNT(*) FROM Tags),
    (SELECT COUNT(*) FROM Badges),
    (SELECT COUNT(*) FROM PostHistory),
    (SELECT COUNT(*) FROM PostLinks),
    (SELECT COUNT(*) FROM LinkTypes),
    (SELECT COUNT(*) FROM PostTypes),
    (SELECT COUNT(*) FROM CloseReasonTypes),
    (SELECT COUNT(*) FROM VoteTypes),
    (SELECT COUNT(*) FROM PostHistoryTypes);
