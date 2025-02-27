
WITH TagArray AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,  
        SUM(v.VoteTypeId = 3) AS DownVotesCount, 
        COUNT(v.UserId) AS TotalVotesGiven 
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        ta.Tag,
        COUNT(ta.PostId) AS TagUsageCount
    FROM 
        TagArray ta
    GROUP BY 
        ta.Tag
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10  
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(VoteTypeId = 2) AS UpVotes,
            SUM(VoteTypeId = 3) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    COALESCE(pt.Tag, 'Uncategorized') AS Tag,
    pd.UpVotes,
    pd.DownVotes,
    us.UpVotesCount,
    us.DownVotesCount,
    us.TotalVotesGiven
FROM 
    PostDetails pd
LEFT JOIN 
    PopularTags pt ON pd.Title LIKE CONCAT('%', pt.Tag, '%')  
LEFT JOIN 
    UserVoteStats us ON pd.OwnerDisplayName = us.DisplayName
ORDER BY 
    pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 50;
