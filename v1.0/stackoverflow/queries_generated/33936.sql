WITH RecursivePostCTE AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Select questions only
    UNION ALL
    SELECT
        p2.Id AS PostId,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        p2.PostTypeId,
        p2.Title,
        p2.CreationDate,
        Level + 1
    FROM
        Posts p2
    INNER JOIN RecursivePostCTE rp ON p2.ParentId = rp.PostId
    WHERE
        p2.PostTypeId = 2  -- Select answers only
),
PostVoteAggregates AS (
    SELECT
        PostId,
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS Upvotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS Downvotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 6) AS CloseVotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 7) AS ReopenVotes
    FROM
        Votes
    GROUP BY
        PostId
),
UserBadgeCounts AS (
    SELECT
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)
SELECT
    p.PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(pva.Upvotes, 0) AS Upvotes,
    COALESCE(pva.Downvotes, 0) AS Downvotes,
    COALESCE(pva.CloseVotes, 0) AS CloseVotes,
    COALESCE(pva.ReopenVotes, 0) AS ReopenVotes,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges,
    rp.Level AS AnswerLevel
FROM
    RecursivePostCTE rp
INNER JOIN
    Posts p ON rp.PostId = p.Id
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    PostVoteAggregates pva ON p.Id = pva.PostId
LEFT JOIN
    UserBadgeCounts ubc ON u.Id = ubc.UserId
WHERE
    rp.Level <= 3  -- Limit the levels of answers we fetch
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit for performance benchmarking
