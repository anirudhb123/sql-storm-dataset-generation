
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @row_number := IF(@prev_location = u.Location, @row_number + 1, 1) AS UserRank,
        @prev_location := u.Location
    FROM 
        Users u, (SELECT @row_number := 0, @prev_location := '') AS vars
    WHERE 
        u.CreationDate < (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    ORDER BY 
        u.Location, u.Reputation DESC
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        @rank := IF(@prev_comment_count = COUNT(c.Id), @rank, @rank + 1) AS CommentRank,
        @prev_comment_count := COUNT(c.Id)
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rank := 0, @prev_comment_count := NULL) AS vars
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL 30 DAY) 
    GROUP BY 
        p.Id, p.OwnerUserId
), 
UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(p.ViewCount) AS TotalViews,
        AVG(ps.CommentCount) AS AverageComments,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS TagsUsed
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStatistics ps ON p.Id = ps.PostId
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1)) AS TagName
        FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6
              UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
        WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, ',', '')) + 1) AS t ON TRUE
    GROUP BY 
        u.Id
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.UserRank,
    p.PostId,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.TotalBountyAmount,
    a.PostsCreated,
    a.TotalViews,
    a.AverageComments,
    a.TagsUsed
FROM 
    RankedUsers u
LEFT JOIN 
    PostStatistics p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    UserPostActivity a ON u.UserId = a.UserId
WHERE 
    p.CommentRank <= 5 
    OR (p.UpVoteCount > p.DownVoteCount AND p.TotalBountyAmount > 0)
ORDER BY 
    u.Reputation DESC, p.CommentCount DESC;
