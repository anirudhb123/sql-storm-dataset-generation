WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
), 
LikelyDuplicates AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    WHERE 
        lt.Id = 3 -- Only consider duplicates
), 
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    WHERE 
        t.IsModeratorOnly = 0
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT pp.Id) AS PostsCreated 
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts pp ON u.Id = pp.OwnerUserId 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    ld.RelatedPostId AS DuplicatePostID,
    tt.TagName AS TopTag,
    ua.DisplayName AS UserDisplayName,
    ua.UpVotes,
    ua.DownVotes,
    ua.PostsCreated
FROM 
    RankedPosts rp
LEFT JOIN 
    LikelyDuplicates ld ON rp.PostID = ld.PostId
LEFT JOIN 
    TopTags tt ON tt.PostCount > 0 -- Join to check if tag exists
LEFT JOIN 
    UserActivity ua ON rp.PostID IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserID)
WHERE 
    rp.RankScore <= 5 -- Get top 5 posts in each type
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
