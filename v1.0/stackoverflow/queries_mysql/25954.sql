
WITH TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        U.Reputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users U ON U.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = U.Id
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName, p.Id, U.Reputation, p.CreationDate, p.Title
),
TagStats AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS QuestionCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        SUM(CommentCount) AS TotalComments,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        TagUsage
    GROUP BY 
        TagName
),
RankedTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalComments,
        TotalBadges,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStats, (SELECT @rank := 0) r
    ORDER BY 
        QuestionCount DESC, TotalUpVotes DESC
)

SELECT 
    TagName,
    QuestionCount,
    TotalUpVotes,
    TotalDownVotes,
    TotalComments,
    TotalBadges,
    Rank
FROM 
    RankedTags
WHERE 
    Rank <= 10 
ORDER BY 
    Rank;
