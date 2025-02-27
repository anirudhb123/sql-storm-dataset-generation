
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.ANSWERCOUNT,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND p.PostTypeId = 1  
),

TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '<>' FROM Tags), '>', numbers.n), '>', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(TRIM(BOTH '<>' FROM Tags)) - CHAR_LENGTH(REPLACE(TRIM(BOTH '<>' FROM Tags), '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),

UserParticipations AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvotesReceived,
        COUNT(CASE WHEN c.UserId IS NOT NULL THEN 1 END) AS CommentsReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    ts.TagName,
    ts.TagCount,
    up.DisplayName AS ActiveUser,
    up.UpvotesReceived,
    up.CommentsReceived
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE CONCAT('%', ts.TagName, '%')
JOIN 
    UserParticipations up ON rp.OwnerDisplayName = up.DisplayName
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
