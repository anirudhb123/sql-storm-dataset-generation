
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
AllPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.Tags,
        p.AcceptedAnswerId,
        COALESCE(Answered.Score, 0) AS AnswerScore,
        COALESCE(VotedDown.DownVoteCount, 0) AS DownVoteScore,
        @rownum := IF(@currentUser = p.OwnerUserId, @rownum + 1, 1) AS UserPostRank,
        @currentUser := p.OwnerUserId
    FROM 
        Posts p
    JOIN (SELECT @rownum := 0, @currentUser := NULL) r
    LEFT JOIN 
        (SELECT 
            ParentId, 
            SUM(Score) AS Score
         FROM 
            Posts 
         WHERE 
            PostTypeId = 2 
         GROUP BY 
            ParentId) AS Answered ON p.Id = Answered.ParentId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS DownVoteCount 
         FROM 
            Votes 
         WHERE 
            VoteTypeId = 3 
         GROUP BY 
            PostId) AS VotedDown ON p.Id = VotedDown.PostId
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.TotalBadges,
    ub.BadgeNames,
    ap.PostId,
    ap.Title,
    ap.Tags,
    CASE 
        WHEN ap.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
        ELSE 'Not Accepted' 
    END AS AnswerStatus,
    ap.AnswerScore,
    ap.DownVoteScore,
    ap.UserPostRank,
    CASE 
        WHEN ap.UserPostRank = 1 
        THEN 'Most Recent Post' 
        ELSE NULL 
    END AS PostRankStatus
FROM 
    UserBadges ub
JOIN 
    AllPosts ap ON ub.UserId = ap.OwnerUserId
WHERE 
    ub.TotalBadges > 0
    AND (ap.Tags LIKE '%SQL%' OR ap.Title LIKE '%SQL%')
    AND NOT EXISTS (
        SELECT 1
        FROM Comments c
        WHERE c.PostId = ap.PostId 
        AND c.UserId = ub.UserId
        AND c.CreationDate > NOW() - INTERVAL 30 DAY
    )
ORDER BY 
    ub.TotalBadges DESC, 
    ap.AnswerScore DESC, 
    ap.PostId DESC;
