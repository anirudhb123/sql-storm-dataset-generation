WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        SUM(c.Score) AS CommentScore,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 
        END AS IsAccepted,
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TagArray
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.VoteCount,
        ue.CommentScore,
        ue.TotalBadgeClass,
        ue.BadgeCount,
        ue.PostCount,
        RANK() OVER (ORDER BY (ue.VoteCount + ue.CommentScore + ue.TotalBadgeClass) DESC) AS EngagementRank
    FROM 
        UserEngagement ue
)
SELECT 
    ps.Title AS PostTitle,
    ps.ViewCount AS TotalViews,
    ps.AnswerCount AS TotalAnswers,
    ps.IsAccepted AS IsAnswerAccepted,
    tc.TagName AS RelatedTag,
    te.DisplayName AS EngagedUser,
    te.VoteCount AS UserVoteCount,
    te.CommentScore AS UserCommentScore,
    te.BadgeCount AS UserBadgeCount
FROM 
    PostStatistics ps
JOIN 
    TagCounts tc ON EXISTS (
        SELECT 1 
        FROM UNNEST(ps.TagArray) AS tag_name 
        WHERE tag_name = tc.TagName
    )
JOIN 
    TopEngagedUsers te ON ps.OwnerUserId = te.UserId
WHERE 
    te.EngagementRank <= 10  -- Limit to top 10 engaged users
ORDER BY 
    ps.ViewCount DESC, te.VoteCount DESC;
