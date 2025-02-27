WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Author,
        pt.Name AS PostTypeName,
        COALESCE(ptt.Name, 'None') AS TagTypeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT DISTINCT ON (PostId) 
            PostId, STRING_AGG(Tags.TagName, ', ') AS Name 
         FROM 
            Posts
         JOIN 
            Tags ON Tags.Id = ANY(STRING_TO_ARRAY(Posts.Tags, ','))
         GROUP BY 
            PostId) ptt ON rp.PostId = ptt.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.Author,
    pd.PostTypeName,
    pd.TagTypeName
FROM 
    PostDetails pd
WHERE 
    pd.Rank <= 5
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;
