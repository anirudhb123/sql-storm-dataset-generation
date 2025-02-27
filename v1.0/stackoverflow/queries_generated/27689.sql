WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
), PostLinksData AS (
    SELECT 
        pl.PostId,
        STRING_AGG(CONCAT('Related Post ID: ', pl.RelatedPostId, ' (Link Type: ', lt.Name, ')'), '; ') AS RelatedPosts
    FROM 
        PostLinks pl
    JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
), PostHistoryCount AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(pl.RelatedPosts, 'No related posts') AS RelatedPosts,
    COALESCE(phc.EditCount, 0) AS EditCount
FROM 
    RankedPosts rp
LEFT JOIN PostLinksData pl ON rp.PostId = pl.PostId
LEFT JOIN PostHistoryCount phc ON rp.PostId = phc.PostId
WHERE 
    rp.rn = 1 -- Ensuring we select the most recent record for each post
ORDER BY 
    rp.CreationDate DESC
LIMIT 10; -- Return only the top 10 recent posts
