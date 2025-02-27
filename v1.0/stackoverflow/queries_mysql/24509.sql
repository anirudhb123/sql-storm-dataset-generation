
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(voteCounts.UpVotes, 0) AS UpVotes,
        COALESCE(voteCounts.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY PostId
    ) voteCounts ON p.Id = voteCounts.PostId
),
TopRatedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.UpVotes,
        tp.DownVotes,
        COALESCE(u.DisplayName, 'Anonymous') AS UserDisplayName,
        SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM 
        TopRatedPosts tp
    LEFT JOIN 
        Posts p ON tp.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT TagName FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
            FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
                  UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
            WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) t) AS t ON TRUE
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.UpVotes, tp.DownVotes, u.DisplayName
),
FinalOutput AS (
    SELECT 
        pd.Title,
        pd.UserDisplayName,
        pd.Score,
        pd.ViewCount,
        pd.UpVotes,
        pd.DownVotes,
        pd.CommentCount,
        pd.Tags,
        CASE 
            WHEN pd.UpVotes > pd.DownVotes THEN 'Positive Post'
            WHEN pd.UpVotes < pd.DownVotes THEN 'Negative Post'
            ELSE 'Neutral Post'
        END AS Sentiment
    FROM 
        PostDetails pd
)
SELECT 
    *,
    CASE 
        WHEN Sentiment = 'Positive Post' AND Score >= 10 THEN 'Hot Content'
        WHEN Sentiment = 'Negative Post' AND Score < 0 THEN 'Needs Attention'
        ELSE 'Standard Post'
    END AS ContentStatus
FROM 
    FinalOutput
WHERE 
    ViewCount IS NOT NULL
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;
