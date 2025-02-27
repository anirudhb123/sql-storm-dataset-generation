
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.OwnerUserId,
        LENGTH(GROUP_CONCAT(p.Tags SEPARATOR ',')) AS TagCount,
        p.Body
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.PostTypeId = 1 
        AND p.ViewCount > 10
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Tags, p.OwnerUserId, p.Body
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(IFNULL(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
        AND p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
PostStatistics AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.TagCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        IFNULL(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        IFNULL(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        FilteredPosts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    GROUP BY 
        p.PostId, p.Title, p.CreationDate, p.TagCount, u.DisplayName
),
RankedPosts AS (
    SELECT 
        ps.*,
        @rank := IF(@prev_upvotes = ps.UpVotes AND @prev_downvotes = ps.DownVotes, @rank, @rank + 1) AS Rank,
        @prev_upvotes := ps.UpVotes,
        @prev_downvotes := ps.DownVotes
    FROM 
        PostStatistics ps
    CROSS JOIN (SELECT @rank := 0, @prev_upvotes := NULL, @prev_downvotes := NULL) r
    ORDER BY 
        ps.UpVotes - ps.DownVotes DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.TagCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.Rank,
    u.TotalBadges
FROM 
    RankedPosts rp
JOIN 
    MostActiveUsers u ON rp.OwnerDisplayName = u.DisplayName
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank;
