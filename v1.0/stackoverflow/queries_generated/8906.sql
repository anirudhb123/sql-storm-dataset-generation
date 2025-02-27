WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostDetails AS (
    SELECT 
        trp.*,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        LATERAL (
            SELECT 
                t.TagName
            FROM 
                Posts p
            JOIN 
                Tags t ON t.ExcerptPostId = p.Id
            WHERE 
                p.Id = trp.PostId
        ) t ON true
    GROUP BY 
        trp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.VoteCount,
    pd.Tags
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;
