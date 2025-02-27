WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.PostTypeId,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.PostTypeId, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High Reputation'
            WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationLevel
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL 
        AND u.CreationDate <= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- post closed
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.AnswerCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    ur.DisplayName AS PostOwner,
    ur.Reputation AS OwnerReputation,
    ur.ReputationLevel,
    cp.CloseReasons,
    COALESCE(cp.CloseCount, 0) AS NumberOfClosures,
    CASE 
        WHEN rp.AnswerCount > 0 THEN (rp.UpvoteCount - rp.DownvoteCount) * 1.0 / NULLIF(rp.AnswerCount, 0)
        ELSE NULL
    END AS VoteAveragePerAnswer
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.CreationDate DESC NULLS LAST;
