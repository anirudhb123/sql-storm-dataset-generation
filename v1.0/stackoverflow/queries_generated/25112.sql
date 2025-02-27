WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC) AS RankByAnswers,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS RankByUpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Body,
        Tags,
        AnswerCount,
        CommentCount,
        UpVotes,
        DownVotes,
        RankByAnswers,
        RankByUpVotes
    FROM 
        RankedPosts
    WHERE 
        RankByAnswers <= 10 OR RankByUpVotes <= 10
),
DetailedPostInfo AS (
    SELECT 
        tp.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        bt.Name AS BadgeName,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        TopRankedPosts tp
    LEFT JOIN 
        Users u ON tp.PostId = u.Id
    LEFT JOIN 
        Badges bt ON u.Id = bt.UserId
    LEFT JOIN 
        PostLinks pl ON tp.PostId = pl.PostId
    GROUP BY 
        tp.PostId, u.DisplayName, u.Reputation, bt.Name
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Body,
    Tags,
    AnswerCount,
    CommentCount,
    UpVotes,
    DownVotes,
    OwnerDisplayName,
    OwnerReputation,
    BadgeName,
    RelatedPostCount
FROM 
    DetailedPostInfo
ORDER BY 
    UpVotes DESC, AnswerCount DESC
LIMIT 50;
