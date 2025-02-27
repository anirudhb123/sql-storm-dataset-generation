
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(v.VoteTypeId) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
), FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.Sentiment,
    u.DisplayName AS AuthorName,
    u.Reputation AS AuthorReputation,
    GROUP_CONCAT(t.TagName) AS Tags
FROM 
    FilteredPosts fp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
LEFT JOIN 
    (SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
     INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS t ON t.TagName IS NOT NULL
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount, 
    fp.CommentCount, fp.UpVotes, fp.DownVotes, 
    fp.Sentiment, u.DisplayName, u.Reputation
ORDER BY 
    fp.ViewCount DESC;
