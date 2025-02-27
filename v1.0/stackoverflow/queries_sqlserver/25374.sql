
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS APPLY (
        SELECT TRIM(value) AS TagName
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) AS t
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostsCreated DESC
)
SELECT TOP 10
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pvc.UpVotes,
    pvc.DownVotes,
    rp.Tags,
    tu.DisplayName AS TopUserDisplayName,
    tu.PostsCreated,
    tu.TotalBadges
FROM 
    RecentPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
CROSS JOIN 
    (SELECT DisplayName, PostsCreated, TotalBadges FROM TopUsers) tu
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;
