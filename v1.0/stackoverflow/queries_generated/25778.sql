WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankWithinType,
        pt.Name AS PostType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_arr ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_arr
    GROUP BY 
        p.Id, pt.Name
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Tags,
        rp.PostType
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankWithinType <= 5
),
UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.Tags,
    tp.PostType,
    uvc.DisplayName AS TopVoter,
    uvc.VoteCount,
    uvc.UpVotes,
    uvc.DownVotes
FROM 
    TopPosts tp
JOIN 
    UserVoteCounts uvc ON uvc.VoteCount = (SELECT MAX(VoteCount) FROM UserVoteCounts)
ORDER BY 
    tp.ViewCount DESC, tp.PostType;

