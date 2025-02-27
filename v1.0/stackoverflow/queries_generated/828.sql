WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        QuestionCount, 
        AnswerCount, 
        TotalBounty, 
        CommentCount,
        RANK() OVER (ORDER BY QuestionCount + AnswerCount DESC) AS ActivityRank
    FROM 
        UserActivity
    WHERE 
        TotalBounty > 0
)
SELECT 
    t.UserId, 
    t.DisplayName,
    t.QuestionCount, 
    t.AnswerCount, 
    t.TotalBounty, 
    t.CommentCount,
    CASE 
        WHEN t.ActivityRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS UserType,
    COALESCE(
        NULLIF(
            (SELECT MAX(c.CreationDate) 
             FROM Comments c 
             WHERE c.UserId = t.UserId AND c.CreationDate <= CURRENT_TIMESTAMP - INTERVAL '30 days'), 
            CURRENT_TIMESTAMP - INTERVAL '30 days'
        ), 
        'No comments in the last 30 days'
    ) AS LastCommentDate,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = t.UserId AND b.Class = 1) AS GoldBadges,
    STRING_AGG(DISTINCT COALESCE(tg.TagName, 'No Tags'), ', ') FILTER (WHERE tg.TagName IS NOT NULL) AS UserTags
FROM 
    TopUsers t
LEFT JOIN 
    Posts p ON p.OwnerUserId = t.UserId
LEFT JOIN 
    STRING_TO_ARRAY(STRING_AGG(p.Tags, ','), ',') AS tg(tagName)
WHERE 
    tg.tagName IS NOT NULL
GROUP BY 
    t.UserId, t.DisplayName, t.QuestionCount, t.AnswerCount, t.TotalBounty, t.CommentCount, t.ActivityRank
ORDER BY 
    t.ActivityRank;
