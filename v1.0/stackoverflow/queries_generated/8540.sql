WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        r.AnswerCount,
        json_agg(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        RankedPosts r
    LEFT JOIN 
        Posts p ON r.PostId = p.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS tag AS t(TagName)
    WHERE 
        r.Rank <= 10
    GROUP BY 
        r.PostId, r.Title, r.CreationDate, r.ViewCount, r.Score, r.AnswerCount
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.Tags,
    pd.CommentCount,
    pd.TotalBounty,
    COALESCE(u.DisplayName, 'Anonymous') AS Author
FROM 
    PostDetails pd
LEFT JOIN 
    Users u ON pd.PostId = u.Id
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
