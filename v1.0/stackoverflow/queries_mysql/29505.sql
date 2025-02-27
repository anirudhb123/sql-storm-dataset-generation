
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagList,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT bh.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 5
),
PostEngagement AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.TagList,
        p.CommentCount,
        p.AnswerCount,
        u.UserId,
        u.DisplayName AS UserDisplayName,
        @row_number := IF(@postId = p.PostId, @row_number + 1, 1) AS UserRank,
        @postId := p.PostId
    FROM 
        RecentPosts p
    JOIN 
        TopUsers u ON TRUE,
        (SELECT @row_number := 0, @postId := NULL) AS vars
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.Score,
    pe.ViewCount,
    pe.TagList,
    pe.CommentCount,
    pe.AnswerCount,
    pe.UserId,
    pe.UserDisplayName,
    pe.UserRank
FROM 
    PostEngagement pe
WHERE 
    pe.UserRank <= 3
ORDER BY 
    pe.PostId, pe.UserRank;
