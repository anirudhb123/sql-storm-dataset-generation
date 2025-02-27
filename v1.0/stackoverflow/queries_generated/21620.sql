WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,  -- Upvotes
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount  -- Downvotes
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Filter for questions only
    GROUP BY
        p.Id, p.OwnerUserId, p.Title, p.ViewCount, p.CreationDate
),

AnswerStats AS (
    SELECT
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN a.Score >= 0 THEN 1 ELSE 0 END) AS NonNegativeAnswerCount
    FROM
        Posts p
    LEFT JOIN
        Posts a ON p.Id = a.ParentId
    WHERE
        p.PostTypeId = 1  -- Questions
    GROUP BY
        p.Id
)

SELECT
    u.Id AS UserId,
    u.DisplayName,
    up.PostId,
    up.Title,
    up.ViewCount,
    up.Rank,
    COALESCE(as.AnswerCount, 0) AS AnswerCount,
    COALESCE(as.NonNegativeAnswerCount, 0) AS NonNegativeAnswerCount,
    CASE 
        WHEN up.UpVoteCount > up.DownVoteCount THEN 'Positive'
        WHEN up.UpVoteCount < up.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM
    Users u
JOIN
    RankedPosts up ON u.Id = up.OwnerUserId
LEFT JOIN
    AnswerStats as ON up.PostId = as.QuestionId
WHERE
    up.Rank = 1  -- Only the top-ranked post per user
ORDER BY
    u.Reputation DESC, up.ViewCount DESC
LIMIT 50;

-- Additionally, include NULL logic to filter out users without any associated posts
AND (up.ViewCount IS NOT NULL OR as.AnswerCount IS NOT NULL);
