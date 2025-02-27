WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Author,
    rp.VoteCount,
    (
        SELECT 
            STRING_AGG(CONCAT(c.UserDisplayName, ': ', c.Text), '; ')
        FROM 
            Comments c 
        WHERE 
            c.PostId = rp.PostId
    ) AS Comments,
    (
        SELECT 
            STRING_AGG(CONCAT(ph.CreationDate, ' - ', pht.Name, ': ', ph.Text), '; ')
        FROM 
            PostHistory ph
        JOIN 
            PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
        WHERE 
            ph.PostId = rp.PostId
    ) AS History
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Rank, rp.VoteCount DESC;

This SQL query generates a report for the top 5 posts by type (questions, answers, etc.) in terms of votes received over the past year. It retrieves the title, body, and tags of each post along with the author's display name and the total number of votes. Additionally, it aggregates comments for each post and provides a history of changes made to each post, including information about the changes' types and their respective timestamps.
