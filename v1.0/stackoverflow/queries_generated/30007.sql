WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        p.LastActivityDate,
        p.AcceptedAnswerId,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        p.LastActivityDate,
        p.AcceptedAnswerId,
        rp.Depth + 1 AS Depth
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId
    WHERE 
        p.PostTypeId = 2 -- Answers
),
PostVoteInsights AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeletionVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.AnswerCount,
    rp.CreationDate,
    rp.LastActivityDate,
    pv.Upvotes,
    pv.Downvotes,
    pv.DeletionVotes,
    COALESCE(bc.GoldBadges, 0) AS GoldBadges,
    COALESCE(bc.SilverBadges, 0) AS SilverBadges,
    COALESCE(bc.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptedStatus,
    DENSE_RANK() OVER (ORDER BY rp.LastActivityDate DESC) AS RecentActivityRank
FROM 
    RecursivePosts rp
LEFT JOIN 
    PostVoteInsights pv ON rp.PostId = pv.PostId
LEFT JOIN 
    BadgeCounts bc ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = bc.UserId)
WHERE 
    rp.Depth = 1 -- Focus on top-level questions
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
