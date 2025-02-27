WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- Up votes
        SUM(v.VoteTypeId = 3) AS DownVoteCount -- Down votes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
PostWithMostRecentEdit AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        p.Id
)
SELECT 
    pwp.PostId,
    pwp.Title,
    pwp.CreationDate,
    pwp.Score,
    pwp.ViewCount,
    pwp.CommentCount,
    pwp.UpVoteCount,
    pwp.DownVoteCount,
    COALESCE(pme.LastEditDate, 'No Edits') AS LastEditDate,
    CASE 
        WHEN pwp.ViewCount IS NULL THEN 'No Views' 
        WHEN pwp.ViewCount < 50 THEN 'Low View Count' 
        ELSE 'High View Count' 
    END AS ViewCategory,
    CASE 
        WHEN pwp.UpVoteCount < pwp.DownVoteCount THEN 'More Downvotes'
        ELSE 'More Upvotes or Equal'
    END AS VoteComparison
FROM 
    RankedPosts pwp
LEFT JOIN 
    PostWithMostRecentEdit pme ON pwp.PostId = pme.PostId
WHERE 
    pwp.rn = 1
ORDER BY 
    pwp.Score DESC, pwp.CreationDate ASC
LIMIT 100;
