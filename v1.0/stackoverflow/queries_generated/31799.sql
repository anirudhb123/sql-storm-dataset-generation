WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
),
RankedPostVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY v.PostId, v.VoteTypeId ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.VoteTypeId
),
LatestPostData AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        COALESCE(AVG(v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(AVG(v.VoteTypeId = 3), 0) AS DownvoteCount,
        CASE 
            WHEN p.LastActivityDate IS NOT NULL THEN DATEDIFF(NOW(), p.LastActivityDate)
            ELSE NULL
        END AS DaysSinceLastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
),
PostStatistics AS (
    SELECT 
        lp.Id,
        lp.Title,
        lp.ViewCount,
        lp.UpvoteCount,
        lp.DownvoteCount,
        COALESCE(c.CloseReason, 'Not Closed') AS CloseReason,
        lp.DaysSinceLastActivity,
        (lp.UpvoteCount - lp.DownvoteCount) AS NetScore
    FROM 
        LatestPostData lp
    LEFT JOIN 
        ClosedPosts c ON lp.Id = c.PostId
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.NetScore,
    ps.CloseReason,
    ps.DaysSinceLastActivity,
    (
        SELECT 
            STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', u.Reputation, ')'), ', ')
        FROM 
            Users u
        WHERE 
            u.Id IN (
                SELECT 
                    p.OwnerUserId
                FROM 
                    Posts p
                WHERE 
                    p.Id = ps.Id
            )
    ) AS OwnerInfo,
    (
        SELECT 
            STRING_AGG(DISTINCT ph.Comment, ', ')
        FROM 
            PostHistory ph
        WHERE 
            ph.PostId = ps.Id AND 
            ph.PostHistoryTypeId IN (12, 13) -- Deleted and Undeleted
    ) AS HistoryComments
FROM 
    PostStatistics ps
ORDER BY 
    ps.NetScore DESC,
    ps.ViewCount DESC
LIMIT 100;
