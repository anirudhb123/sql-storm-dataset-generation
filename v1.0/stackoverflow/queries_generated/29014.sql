WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Last year
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        STRING_AGG(t.TagName, ', ') AS Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.PostRank,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON rp.PostId = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVoteCount 
         FROM Votes 
         WHERE VoteTypeId = 2 -- Upvotes 
         GROUP BY PostId) v ON rp.PostId = v.PostId
    LEFT JOIN 
        (SELECT pt.TagName, pt.Id AS PostTagId 
         FROM Tags pt
         JOIN Posts p ON p.Tags LIKE '%' + pt.TagName + '%') AS tag ON rp.PostId = tag.PostTagId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.CreationDate, rp.PostRank
)
SELECT 
    pd.Title,
    pd.Body,
    pd.Tags,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.CommentCount,
    pd.UpVoteCount,
    CASE 
        WHEN pd.PostRank = 1 THEN 'Most Recent'
        ELSE 'Older Post'
    END AS PostAgeCategory
FROM 
    PostDetails pd
ORDER BY 
    pd.CreationDate DESC,
    pd.UpVoteCount DESC;
