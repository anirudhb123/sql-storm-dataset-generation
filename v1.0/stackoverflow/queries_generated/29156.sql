WITH TagData AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS PostCount,
        STRING_AGG(DISTINCT P.Title, ', ') AS PostTitles,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS Authors,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        T.TagName
),
BadgeStats AS (
    SELECT 
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.DisplayName
),
VoteStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id
)
SELECT 
    TD.TagName,
    TD.PostCount,
    TD.PostTitles,
    TD.Authors,
    BS.BadgeCount AS AuthorBadgeCount,
    BS.BadgeNames AS AuthorBadges,
    VS.UpVotes AS PostUpVotes,
    VS.DownVotes AS PostDownVotes
FROM 
    TagData TD
JOIN 
    BadgeStats BS ON TD.Authors LIKE '%' || BS.DisplayName || '%'
JOIN 
    VoteStats VS ON VS.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || TD.TagName || '%')
ORDER BY 
    TD.PostCount DESC, TD.TagName;
