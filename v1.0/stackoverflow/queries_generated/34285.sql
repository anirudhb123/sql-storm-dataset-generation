WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Only questions
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
DistinctAuthors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Authors with more than 5 posts
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ': ', ph.Comment), '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Title/Body/Tags edited
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    rp.rn,
    COALESCE(v.Upvotes, 0) AS Upvotes,
    COALESCE(v.Downvotes, 0) AS Downvotes,
    COALESCE(e.EditCount, 0) AS TotalEdits,
    COALESCE(e.EditComments, 'No edits') AS LastEditComments,
    a.UserId,
    a.DisplayName,
    a.PostCount
FROM 
    RankedPosts rp
JOIN 
    PostVotes v ON rp.PostId = v.PostId
JOIN 
    RecentPostHistory e ON rp.PostId = e.PostId
JOIN 
    DistinctAuthors a ON rp.PostId = ANY(ARRAY(SELECT p.Id FROM Posts p WHERE p.OwnerUserId = a.UserId))
WHERE 
    rp.rn = 1  -- Most recent post of each author
ORDER BY 
    p.CreationDate DESC
LIMIT 50;
