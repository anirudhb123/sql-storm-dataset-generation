WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '<>')) AS t(TagName) ON t.TagName IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
),
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.Score,
        pm.ViewCount,
        pm.AnswerCount,
        pm.CommentCount,
        pm.LastEditDate,
        pm.Tags,
        U.DisplayName,
        US.Upvotes,
        US.Downvotes
    FROM 
        PostMetrics pm
    JOIN 
        Users U ON pm.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = U.Id)
    JOIN 
        UserStats US ON U.Id = US.UserId
    WHERE 
        pm.Score > 5 AND pm.ViewCount > 100
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.LastEditDate IS NULL THEN 'No Edits'
        ELSE 'Edited Recently'
    END AS EditStatus
FROM 
    TopPosts rp
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10;
