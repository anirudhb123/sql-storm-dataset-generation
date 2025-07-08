
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND /* Only questions */
        p.CreationDate >= DATEADD(year, -1, CURRENT_DATE()) /* Questions from the last year */
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        LATERAL SPLIT_TO_TABLE(Tags, '>') AS value
    WHERE 
        PostTypeId = 1 /* Only questions */
    GROUP BY 
        TRIM(value)
    HAVING 
        COUNT(*) > 5 /* Tags used more than 5 times */
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(c.Score) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 /* Only questions */
    GROUP BY 
        p.Id
),
PostsWithBadge AS (
    SELECT 
        p.Id AS PostId,
        b.Name AS BadgeName
    FROM 
        Posts p
    JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1 /* Only questions */
        AND b.Class = 1 /* Only Gold badges */
        AND b.Date >= DATEADD(year, -1, CURRENT_DATE()) /* Received last year */
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    pt.TagName,
    pc.CommentCount,
    pc.TotalCommentScore,
    pb.BadgeName
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT TRIM(value) FROM LATERAL SPLIT_TO_TABLE(rp.Tags, '>') AS value)
LEFT JOIN 
    PostWithComments pc ON pc.PostId = rp.PostId
LEFT JOIN 
    PostsWithBadge pb ON pb.PostId = rp.PostId
WHERE 
    rp.PostRank = 1 /* Get only the latest question for each user */
ORDER BY 
    rp.Score DESC, /* Order by score */
    pc.CommentCount DESC;
