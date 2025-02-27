WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        u.DisplayName AS OwnerName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.CreationDate) AS LastInteractionDate
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        PostId
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS TotalEdits,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edits to Title, Body, Tags
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    ps.CommentCount,
    ps.TotalBounty,
    phs.TotalEdits,
    rp.UserPostRank,
    rp.OwnerName,
    rp.Tags,
    ps.LastInteractionDate,
    phs.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostStats ps ON rp.PostId = ps.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.UserPostRank <= 5  -- Get top 5 recent posts per user
ORDER BY 
    rp.OwnerName, rp.CreationDate DESC;
