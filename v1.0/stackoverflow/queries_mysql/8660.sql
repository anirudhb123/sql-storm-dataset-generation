
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        @row_number:=IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_post_type := NULL) AS init
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    ORDER BY 
        p.PostTypeId, p.Score DESC, p.CreationDate DESC
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(v.Id) > 10 
),
PostWithUserVotes AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        pu.UserId,
        pu.DisplayName,
        pu.VoteCount
    FROM 
        TopPosts tp
    JOIN 
        Votes v ON tp.PostId = v.PostId
    JOIN 
        PopularUsers pu ON v.UserId = pu.UserId
)
SELECT 
    pw.PostId,
    pw.Title,
    pw.Score,
    pw.ViewCount,
    pu.DisplayName AS Voter,
    pu.VoteCount
FROM 
    PostWithUserVotes pw
JOIN 
    PopularUsers pu ON pw.UserId = pu.UserId
ORDER BY 
    pw.Score DESC, pw.ViewCount DESC;
