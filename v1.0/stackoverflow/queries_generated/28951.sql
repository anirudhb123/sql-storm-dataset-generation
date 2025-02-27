WITH TagStats AS (
    SELECT 
        TRIM(SUBSTRING(tag, 2, LENGTH(tag) - 2)) AS CleanTag,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p,
        UNNEST(string_to_array(p.Tags, '>')) AS tag
    WHERE 
        tag <> ''
    GROUP BY 
        CleanTag
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId IN (2), 0)) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId IN (3), 0)) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        p.Title,
        p.Body,
        ph.Comment,
        p.ViewCount,
        p.AcceptedAnswerId
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
        AND ph.CreationDate >= NOW() - INTERVAL '30 days'
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.UserId) AS EditorsCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.LastActivityDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title
)

SELECT 
    ts.CleanTag,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ue.UserId,
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalViews,
    ue.UpVotes,
    ue.DownVotes,
    ra.PostId,
    ra.Title,
    ra.CommentCount,
    ra.EditorsCount,
    ra.LastEditDate
FROM 
    TagStats ts
JOIN 
    UserEngagement ue ON ts.PostCount > 10
LEFT JOIN 
    RecentActivity ra ON ra.PostId = ts.PostCount
ORDER BY 
    ts.PostCount DESC, ue.TotalPosts DESC, ra.LastEditDate DESC
LIMIT 100;
