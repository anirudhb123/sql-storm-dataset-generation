WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed
),
CountVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostAuthors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.Class, 0) AS BadgeClass,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badge
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.PostTypeId,
    pa.DisplayName AS Author,
    pa.Reputation,
    COALESCE(cv.UpVotes, 0) AS UpVotes,
    COALESCE(cv.DownVotes, 0) AS DownVotes,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN rp.CreationDate >= CURRENT_DATE - INTERVAL '1 week' THEN 1 ELSE 0 END) OVER () AS PostsInLastWeek,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RecentPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    CountVotes cv ON rp.PostId = cv.PostId
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    PostAuthors pa ON rp.OwnerUserId = pa.UserId
LEFT JOIN 
    LATERAL (
        SELECT 
            string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TagName
        FROM 
            Posts p 
        WHERE 
            p.Id = rp.PostId
    ) AS t ON TRUE
WHERE 
    rp.rn = 1 -- Only take the most recent post per user
GROUP BY 
    rp.PostId, pa.DisplayName, pa.Reputation, rp.CreationDate, rp.PostTypeId, 
    rp.AcceptedAnswerId, cp.CloseReason
ORDER BY 
    rp.CreationDate DESC;
