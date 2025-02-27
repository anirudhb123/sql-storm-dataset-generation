WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, IsModeratorOnly, IsRequired, 0 AS Level
    FROM Tags
    WHERE IsRequired = 1
    
    UNION ALL
    
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, t.IsModeratorOnly, t.IsRequired, rh.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy rh ON t.WikiPostId = rh.Id
)
, UserPostCount AS (
    SELECT  u.Id AS UserId,
            u.DisplayName,
            COUNT(p.Id) AS PostCount,
            SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
            SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
            SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)
, UserBadges AS (
    SELECT b.UserId,
           COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
, AvgVotes AS (
    SELECT p.OwnerUserId,
           AVG(vs.VoteCount) AS AvgVotes
    FROM Posts p
    LEFT JOIN (
        SELECT VoteTypeId, PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY VoteTypeId, PostId
    ) vs ON p.Id = vs.PostId
    GROUP BY p.OwnerUserId
)

SELECT u.UserId,
       u.DisplayName,
       u.PostCount,
       u.QuestionCount,
       u.AnswerCount,
       u.AcceptedAnswerCount,
       b.GoldBadges,
       b.SilverBadges,
       b.BronzeBadges,
       COALESCE(av.AvgVotes, 0) AS AvgVotes,
       STRING_AGG(DISTINCT th.TagName, ', ') AS RequiredTags
FROM UserPostCount u
LEFT JOIN UserBadges b ON u.UserId = b.UserId
LEFT JOIN AvgVotes av ON u.UserId = av.OwnerUserId
JOIN RecursiveTagHierarchy th ON th.IsRequired = 1
GROUP BY u.UserId, u.DisplayName, u.PostCount, u.QuestionCount, u.AnswerCount, u.AcceptedAnswerCount, b.GoldBadges, b.SilverBadges, b.BronzeBadges, av.AvgVotes
ORDER BY u.PostCount DESC, u.QuestionCount DESC, b.GoldBadges DESC;
