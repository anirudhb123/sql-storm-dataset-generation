WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ps.AnswerCount,
        COALESCE(sum(c.Id), 0) AS CommentCount,
        COALESCE(sum(p2.ViewCount), 0) AS TotalViewCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts ps ON p.Id = ps.ParentId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Posts p2 ON pl.RelatedPostId = p2.Id
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, ps.AnswerCount
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.QuestionCount,
    us.AnswerCount,
    SUM(pi.CommentCount) AS TotalComments,
    SUM(pi.TotalViewCount) AS TotalViews,
    SUM(us.UpVotes) AS TotalUpVotes,
    SUM(us.DownVotes) AS TotalDownVotes
FROM 
    UserStats us
JOIN 
    PostInteraction pi ON us.UserId = pi.OwnerDisplayName
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.BadgeCount, us.QuestionCount, us.AnswerCount
ORDER BY 
    us.Reputation DESC
LIMIT 10;
