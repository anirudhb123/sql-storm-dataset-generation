WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        DENSE_RANK() OVER (PARTITION BY DATE_TRUNC('month', p.CreationDate) ORDER BY p.Score DESC) AS RankInMonth
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
        AND p.Score > 0
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS QuestionsWithAcceptedAnswers,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
TopRatedPosts AS (
    SELECT
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        us.DisplayName AS UserDisplayName,
        us.TotalQuestions,
        us.QuestionsWithAcceptedAnswers,
        us.TotalBadges
    FROM
        RankedPosts rp
    JOIN
        Users u ON rp.Id IN (SELECT DISTINCT ParentId FROM Posts WHERE OwnerUserId = u.Id)
    JOIN
        UserStatistics us ON u.Id = us.UserId
    WHERE
        rp.RankInMonth <= 5
)
SELECT
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.UserDisplayName,
    trp.TotalQuestions,
    trp.QuestionsWithAcceptedAnswers,
    trp.TotalBadges,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM
    TopRatedPosts trp
LEFT JOIN
    Comments c ON trp.PostId = c.PostId
LEFT JOIN
    Votes v ON trp.PostId = v.PostId
GROUP BY
    trp.PostId, trp.Title, trp.CreationDate, trp.Score, trp.UserDisplayName, trp.TotalQuestions, trp.QuestionsWithAcceptedAnswers, trp.TotalBadges
ORDER BY
    trp.Score DESC, trp.CreationDate DESC
LIMIT 100;
