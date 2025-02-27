WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName
),
HighEngagementPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        Score,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10 -- Top 10 for each post type
),
TagsAggregated AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(Tags, '>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagsAggregated
    WHERE 
        TagCount >= 5 -- Tags used in at least 5 posts
)
SELECT 
    hp.PostId,
    hp.Title,
    hp.OwnerDisplayName,
    hp.CreationDate,
    hp.ViewCount,
    hp.Score,
    hp.CommentCount,
    hp.VoteCount,
    STRING_AGG(tt.TagName, ', ') AS RelatedTags
FROM 
    HighEngagementPosts hp
LEFT JOIN 
    TopTags tt ON hp.Tags LIKE '%' || tt.TagName || '%'
GROUP BY 
    hp.PostId, hp.Title, hp.OwnerDisplayName, hp.CreationDate, hp.ViewCount, hp.Score, hp.CommentCount, hp.VoteCount
ORDER BY 
    hp.Score DESC, hp.ViewCount DESC;
