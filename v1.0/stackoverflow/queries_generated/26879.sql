WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        categorization.PostType,
        RANK() OVER (PARTITION BY categorization.PostType ORDER BY p.Score DESC) AS rank_score
    FROM 
        Posts p
    CROSS JOIN (
        SELECT 
            pt.Id AS PostTypeId, 
            pt.Name AS PostType
        FROM 
            PostTypes pt
    ) categorization ON p.PostTypeId = categorization.PostTypeId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostTagCounts AS (
    SELECT 
        PostId,
        COUNT(DISTINCT TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><')))) ) AS TagCount
    FROM 
        Posts
    GROUP BY 
        PostId
),
TopPostsWithTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.PostType,
        rp.rank_score,
        ptc.TagCount
    FROM 
        RankedPosts rp
    JOIN 
        PostTagCounts ptc ON rp.PostId = ptc.PostId
    WHERE 
        rp.rank_score <= 5 -- Considering only top 5 posts per type
)
SELECT 
    t.Title,
    t.PostType,
    t.CreatedDate,
    t.TagCount,
    U.DisplayName AS TopUser,
    U.Reputation
FROM 
    TopPostsWithTags t
JOIN 
    Users U ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId)
ORDER BY 
    TagCount DESC, 
    t.CreatedDate DESC;
