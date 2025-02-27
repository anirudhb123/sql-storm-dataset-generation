WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.Description, 'No Accepted Answer') AS AcceptedAnswerDescription,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, a.Description, u.DisplayName
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPosts
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AcceptedAnswerDescription,
    rp.OwnerDisplayName,
    ra.QuestionsAsked,
    ra.UpvotesReceived,
    ra.DownvotesReceived,
    phs.HistoryCount,
    phs.ClosedPosts,
    phs.ReopenedPosts
FROM 
    RankedPosts rp
JOIN 
    RecentActivity ra ON rp.OwnerDisplayName = ra.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
