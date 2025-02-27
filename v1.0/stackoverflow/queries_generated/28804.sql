WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        RANK() OVER (ORDER BY COALESCE(p.Score, 0) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only select Questions
    GROUP BY 
        p.Id, u.DisplayName
),

TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount,
        AVG(user.Reputation) AS AvgUserReputation
    FROM
        Tags t
    LEFT JOIN 
        Posts pt ON pt.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users user ON pt.OwnerUserId = user.Id
    GROUP BY 
        t.TagName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Author,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.PostRank,
    ts.TagName,
    ts.PostCount,
    ts.AvgUserReputation
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE CONCAT('%<', ts.TagName, '>%')
ORDER BY 
    rp.PostRank, ts.PostCount DESC;
