WITH RankedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT ct.Name, ', ') AS ClosedReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    uq.UserId,
    uq.DisplayName,
    rq.QuestionId,
    rq.Title,
    uq.TotalBounty,
    uq.Upvotes,
    uq.Downvotes,
    uq.PostCount,
    rq.CreationDate,
    rq.Score,
    rq.ViewCount,
    cp.LastClosedDate,
    cp.ClosedReason
FROM 
    UserScores uq
INNER JOIN 
    RankedQuestions rq ON uq.UserId = rq.OwnerUserId AND rq.rn = 1
LEFT JOIN 
    ClosedPosts cp ON rq.QuestionId = cp.PostId
WHERE 
    uq.TotalBounty > 0 OR uq.Upvotes > uq.Downvotes
ORDER BY 
    uq.TotalBounty DESC, rq.Score DESC
LIMIT 10;
