WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.ClosedDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- We are only interested in Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        DATEDIFF(NOW(), u.CreationDate) AS DaysSinceRegistration
    FROM 
        Users u
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
),
ActivePosts AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, 
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    LEFT JOIN Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId
),
TopPosts AS (
    SELECT 
        ap.PostId, 
        ap.CommentCount, 
        ap.UpVotes, 
        ap.DownVotes,
        (ap.UpVotes - ap.DownVotes) AS NetVotes
    FROM 
        ActivePosts ap
    WHERE 
        ap.CommentCount > 5 -- Filter to only posts with more than 5 comments
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edited Title, Body, Tags
    GROUP BY 
        ph.PostId
)

SELECT 
    pu.UserId, 
    pu.DisplayName, 
    pp.PostId, 
    pp.CommentCount, 
    pp.NetVotes,
    COALESCE(ph.EditCount, 0) AS EditCount,
    CASE 
        WHEN pp.NetVotes > 10 THEN 'Highly Engaging'
        WHEN pp.NetVotes BETWEEN 1 AND 10 THEN 'Moderately Engaging'
        ELSE 'Not Engaging'
    END AS EngagementLevel
FROM 
    RecentUsers pu
JOIN 
    TopPosts pp ON pu.UserId = pp.PostId
LEFT JOIN 
    PostHistoryCounts ph ON pp.PostId = ph.PostId
WHERE 
    pu.DaysSinceRegistration <= 30 -- Only consider users registered in the last 30 days
ORDER BY 
    pp.NetVotes DESC, 
    pp.CommentCount DESC;
