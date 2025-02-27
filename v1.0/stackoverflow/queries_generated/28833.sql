WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastEditDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')) AS t(TagName) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastEditDate, p.ViewCount
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.LastEditDate,
    pd.ViewCount,
    pd.CommentCount,
    pd.AnswerCount,
    pd.Tags,
    ua.DisplayName AS UserDisplayName,
    ua.BadgeCount,
    ua.TotalBounty
FROM 
    PostDetails pd
JOIN 
    Users u ON pd.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
JOIN 
    UserActivity ua ON u.Id = ua.UserId
WHERE 
    pd.ViewCount > 100
ORDER BY 
    pd.ViewCount DESC, 
    pd.CreationDate DESC
LIMIT 50;
