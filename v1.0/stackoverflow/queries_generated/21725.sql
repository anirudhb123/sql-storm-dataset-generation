WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY u.Id) AS CumulativeUpVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
QuestionAnswerStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN pt.Name = 'Question' THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN pt.Name = 'Answer' AND p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswerCount,
        COUNT(CASE WHEN pt.Name = 'Answer' AND p.AcceptedAnswerId IS NULL THEN 1 END) AS UnacceptedAnswerCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.OwnerUserId
),
UserBadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CombinedStats AS (
    SELECT 
        uvs.UserId,
        uvs.DisplayName,
        COALESCE(qas.QuestionCount, 0) AS QuestionCount,
        COALESCE(qas.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        COALESCE(qas.UnacceptedAnswerCount, 0) AS UnacceptedAnswerCount,
        COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
        COALESCE(ubs.SilverBadges, 0) AS SilverBadges,
        COALESCE(ubs.BronzeBadges, 0) AS BronzeBadges,
        uvs.UpVotes,
        uvs.DownVotes,
        uvs.TotalVotes,
        uvs.CumulativeUpVotes,
        ROW_NUMBER() OVER(ORDER BY uvs.UpVotes DESC, uvs.TotalVotes DESC) AS Rank
    FROM 
        UserVoteStats uvs
    LEFT JOIN 
        QuestionAnswerStats qas ON uvs.UserId = qas.OwnerUserId
    LEFT JOIN 
        UserBadgeStats ubs ON uvs.UserId = ubs.UserId
)
SELECT 
    cs.DisplayName,
    cs.QuestionCount,
    cs.AcceptedAnswerCount,
    cs.UnacceptedAnswerCount,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges,
    cs.UpVotes,
    cs.DownVotes,
    cs.TotalVotes,
    cs.CumulativeUpVotes,
    cs.Rank,
    CASE 
        WHEN cs.UpVotes > cs.DownVotes THEN 'Positive Influence'
        WHEN cs.UpVotes < cs.DownVotes THEN 'Negative Influence'
        ELSE 'Neutral Influence'
    END AS Influence
FROM 
    CombinedStats cs
WHERE 
    cs.QuestionCount > 0
ORDER BY 
    cs.Rank
LIMIT 10;

