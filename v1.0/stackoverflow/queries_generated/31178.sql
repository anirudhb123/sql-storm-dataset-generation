WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.Views,
        u.UpVotes,
        u.DownVotes
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostHistoryWithDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.Comment,
        p.Title AS EditedTitle,
        pt.Name AS PostType,
        ph.UserDisplayName AS EditorName,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deleted/Undeleted'
            ELSE 'Edited'
        END AS EditAction
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) THEN 'Has Upvotes'
            ELSE 'No Upvotes'
        END AS VoteStatus,
        (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
         FROM STRING_SPLIT(rp.Tags, '<>') AS t) AS TagsList
    FROM 
        RankedPosts rp
    WHERE 
        RankByScore <= 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pp.VoteStatus,
    pp.TagsList,
    uh.UserId,
    uh.DisplayName AS UserDisplayName,
    ph.EditDate,
    ph.EditAction,
    ph.EditedTitle,
    ph.EditorName
FROM 
    PopularPosts pp
LEFT JOIN 
    UserReputation uh ON pp.ViewCount > uh.Views
LEFT JOIN 
    PostHistoryWithDetails ph ON pp.PostId = ph.PostId
WHERE 
    pp.Score > 10
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC, pp.CommentCount DESC;
