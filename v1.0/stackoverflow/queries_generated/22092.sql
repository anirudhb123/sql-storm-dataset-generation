WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.CreationDate,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t(TagName)
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.RankScore,
        rp.CommentCount,
        rp.CreationDate,
        rp.TagsList,
        bt.Name AS BadgeName,
        u.Reputation,
        COALESCE(u.Location, 'Not specified') AS UserLocation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        Badges bt ON u.Id = bt.UserId AND bt.Class = 1
),
FilteredPosts AS (
    SELECT 
        pd.*,
        CASE 
            WHEN pd.Score IS NULL THEN 'No Score'
            WHEN pd.Score > 100 THEN 'High Score'
            ELSE 'Moderate Score'
        END AS ScoreCategory,
        CASE 
            WHEN pd.CommentCount = 0 THEN 'No Comments'
            WHEN pd.CommentCount BETWEEN 1 AND 5 THEN 'Few Comments'
            ELSE 'Many Comments'
        END AS CommentCategory
    FROM 
        PostDetails pd
    WHERE 
        pd.RankScore <= 5 -- Get top 5 posts per PostType
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ScoreCategory,
    fp.CommentCategory,
    fp.BadgeName,
    fp.UserLocation,
    ARRAY_LENGTH(fp.TagsList, 1) AS TagCount,
    COUNT(v.Id) OVER (PARTITION BY fp.PostId) AS VoteCount,
    FIRST_VALUE(fp.CreationDate) OVER (PARTITION BY fp.UserLocation ORDER BY fp.CreationDate ASC) AS FirstPostDateOfLocation
FROM 
    FilteredPosts fp
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId
WHERE 
    fp.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '30 days')
ORDER BY 
    fp.Score DESC NULLS LAST,
    fp.Title ASC;
