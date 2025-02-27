WITH RecursivePosts AS (
    SELECT 
        Id,
        Title,
        OwnerUserId,
        ParentId,
        CreationDate,
        Score,
        1 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.CreationDate,
        p.Score,
        rp.Level + 1 AS Level
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(p.Score) AS CurrentScore,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY p.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 5
),
FinalOutput AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerDisplayName,
        ps.CommentCount,
        ps.UpVoteCount - ps.DownVoteCount AS NetVotes,
        ps.CurrentScore,
        ps.CreationDate,
        COALESCE(bt.GoldBadges, 0) AS GoldBadges,
        COALESCE(bt.SilverBadges, 0) AS SilverBadges,
        COALESCE(bt.BronzeBadges, 0) AS BronzeBadges,
        pt.TagName
    FROM PostStatistics ps
    LEFT JOIN (
        SELECT UserId,
            SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
            SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
            SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
        FROM Badges b
        GROUP BY UserId
    ) bt ON ps.OwnerUserId = bt.UserId
    LEFT JOIN PopularTags pt ON pt.PostCount > (SELECT AVG(PostCount) FROM PopularTags)
)
SELECT 
    fo.PostId,
    fo.Title,
    fo.OwnerDisplayName,
    fo.CommentCount,
    fo.NetVotes,
    fo.CurrentScore,
    fo.CreationDate,
    STRING_AGG(fo.TagName, ', ') AS PopularTags,
    ROW_NUMBER() OVER (PARTITION BY fo.OwnerDisplayName ORDER BY fo.CurrentScore DESC) AS RankByScore
FROM FinalOutput fo
GROUP BY fo.PostId, fo.Title, fo.OwnerDisplayName, fo.CommentCount, fo.NetVotes, fo.CurrentScore, fo.CreationDate
ORDER BY fo.CurrentScore DESC, fo.CommentCount DESC;
