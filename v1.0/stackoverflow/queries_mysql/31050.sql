
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        @row_num := IF(@prev_post = p.PostTypeId, @row_num + 1, 1) AS Rank,
        @prev_post := p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_num := 0, @prev_post := NULL) AS vars
    WHERE
        p.CreationDate > DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopComments AS (
    SELECT
        c.PostId,
        c.Text AS Comment,
        c.CreationDate,
        @comment_row_num := IF(@prev_comment_post = c.PostId, @comment_row_num + 1, 1) AS CommentRank,
        @prev_comment_post := c.PostId
    FROM
        Comments c
    CROSS JOIN (SELECT @comment_row_num := 0, @prev_comment_post := NULL) AS vars
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        pht.Name AS HistoryType,
        ph.Comment
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE
        ph.CreationDate > DATE_SUB('2024-10-01', INTERVAL 60 DAY) AND
        ph.PostHistoryTypeId IN (10, 11, 12)  
),
FinalResults AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate AS PostDate,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.NetVotes,
        tc.Comment AS LatestComment,
        ph.UserId AS HistoryUserId,
        ph.HistoryType,
        ph.CreationDate AS HistoryDate
    FROM
        RankedPosts rp
    LEFT JOIN
        TopComments tc ON rp.PostId = tc.PostId AND tc.CommentRank = 1
    LEFT JOIN
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    WHERE
        rp.Rank <= 5 
)
SELECT
    fr.PostId,
    fr.Title,
    fr.PostDate,
    fr.Score,
    fr.ViewCount,
    fr.Author,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.NetVotes,
    fr.LatestComment,
    COALESCE(fr.HistoryType, 'None') AS HistoryType,
    COALESCE(fr.HistoryDate, NULL) AS HistoryDate
FROM
    FinalResults fr
ORDER BY
    fr.Score DESC
LIMIT 100;
