WITH RecursiveTagHierarchy AS (
    SELECT 
        Id AS TagId, 
        TagName, 
        1 AS Depth,
        CAST(TagName AS VARCHAR(50)) AS Path
    FROM Tags
    WHERE IsModeratorOnly = 0
    
    UNION ALL
    
    SELECT 
        tl.RelatedPostId AS TagId,
        t.TagName, 
        r.Depth + 1,
        CONCAT(r.Path, ' -> ', t.TagName)
    FROM PostLinks tl
    JOIN Posts p ON p.Id = tl.PostId
    JOIN Tags t ON t.Id = p.Id
    JOIN RecursiveTagHierarchy r ON r.TagId = tl.PostId
)

SELECT 
    t.TagName,
    COUNT(p.Id) AS PostCount,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,
    SUM(v.VoteTypeId = 3) AS TotalDownVotes,
    SUM(CASE WHEN (bh.Class = 1) THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN (bh.Class = 2) THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN (bh.Class = 3) THEN 1 ELSE 0 END) AS BronzeBadges,
    COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.AcceptedAnswerId END) AS AcceptedAnswers,
    MAX(bh.Date) AS LastBadgeAwarded
FROM Tags t
LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
LEFT JOIN Votes v ON v.PostId = p.Id
LEFT JOIN Badges bh ON bh.UserId = p.OwnerUserId
WHERE t.Count > 10
GROUP BY t.TagName
ORDER BY PostCount DESC, TotalUpVotes DESC
LIMIT 10;

-- This SQL query benchmarks string processing by analyzing posts with popular tags, counting posts, votes, badges and analyzing contributions of users for the most prevalent tags.
